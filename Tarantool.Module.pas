unit Tarantool.Module;

interface
{$IfDef UNIX}
type
  fiber_attr = pointer;
  fiber = pointer;
  fiber_cond = pointer;
  fiber_func = function (args: array of const): integer; cdecl;

type
  ssize_t = integer;


function fiber_attr_new: fiber_attr; cdecl; external;
procedure fiber_attr_delete(pfiber_attr: fiber_attr); cdecl; external;
function fiber_attr_setstacksize(pfiber_attr: fiber_attr; stack_size: SIZE_T): integer; cdecl; external;
function fiber_attr_getstacksize(pfiber_attr: fiber_attr): SIZE_T; cdecl; external;
function fiber_self: fiber; cdecl; external;
function fiber_new(const name: pchar; f: fiber_func): fiber; cdecl; external;
function fiber_new_ex(const name: pchar; pfiber_attr: fiber_attr; f: fiber_func): fiber; cdecl; external;
procedure fiber_yeld; cdecl; external;
procedure fiber_start(callee: fiber; args: array of const); cdecl; external;
procedure fiber_wakeup(f: fiber); cdecl; external;
procedure fiber_cancel(f: fiber); cdecl; external;
function fiber_set_cancellable(yesno: Boolean): Boolean; cdecl; external;
procedure fiber_set_joinable(f: fiber; yesno: Boolean); cdecl; external;
function fiber_join(f: fiber): integer; cdecl; external;
procedure fiber_sleep(s: double); cdecl; external;
function fiber_is_cancelled: boolean; cdecl; external;
function fiber_time: Double; cdecl; external;
function fiber_time64: UInt64; cdecl; external;
function fiber_clock: double; cdecl; external;
function fiber_clock64: UInt64; cdecl; external;
procedure fiber_reschedule; cdecl; external;
function fiber_cond_new: fiber_cond; cdecl; external;
procedure fiber_cond_delete(cond: fiber_cond); cdecl; external;
procedure fiber_cond_signal(cond: fiber_cond); cdecl; external;
procedure fiber_cond_broadcast(cond: fiber_cond); cdecl; external;
function fiber_cond_wait_timeout(cond: fiber_cond; timeout: Double): integer; cdecl; external;
function fiber_cond_wait(cond: fiber_cond): integer; cdecl; external;

type enum_coio = (
	//** READ event */
	COIO_READ  = 1,
	//** WRITE event */
	COIO_WRITE = 2
);

(**
 * Wait until READ or WRITE event on socket (\a fd). Yields.
 * \param fd - non-blocking socket file description
 * \param events - requested events to wait.
 * Combination of TNT_IO_READ | TNT_IO_WRITE bit flags.
 * \param timeoout - timeout in seconds.
 * \retval 0 - timeout
 * \retval >0 - returned events. Combination of TNT_IO_READ | TNT_IO_WRITE
 * bit flags.
 *)
function coio_wait(fd: Integer; event: Integer; timeout: Double): integer; cdecl; external;

(**
 * Close the fd and wake any fiber blocked in
 * coio_wait() call on this fd.
 *)
function coio_close(fd: integer): integer; cdecl; external;

(**
 * Create new eio task with specified function and
 * arguments. Yield and wait until the task is complete
 * or a timeout occurs.
 *
 * This function doesn't throw exceptions to avoid double error
 * checking: in most cases it's also necessary to check the return
 * value of the called function and perform necessary actions. If
 * func sets errno, the errno is preserved across the call.
 *
 * @retval -1 and errno = ENOMEM if failed to create a task
 * @retval the function return (errno is preserved).
 *
 * @code
 *	static ssize_t openfile_cb(va_list ap)
 *	{
 *	         const char *filename = va_arg(ap);
 *	         int flags = va_arg(ap);
 *	         return open(filename, flags);
 *	}
 *
 *	if (coio_call(openfile_cb, 0.10, "/tmp/file", 0) == -1)
 *		// handle errors.
 *	...
 * @endcode
 *)
type
  coio_callback = function (args: array of const): ssize_t; cdecl;

function coio_call(f: coio_callback;  args: array of Const): ssize_t; cdecl; external;

type
    addrinfo = pointer;
    paddrinfo = ^addrinfo;
(**
 * Fiber-friendly version of getaddrinfo(3).
 *
 * @param host host name, i.e. "tarantool.org"
 * @param port service name, i.e. "80" or "http"
 * @param hints hints, see getaddrinfo(3)
 * @param res[out] result, see getaddrinfo(3)
 * @param timeout timeout
 * @retval  0 on success, please free @a res using freeaddrinfo(3).
 * @retval -1 on error, check diag.
 *            Please note that the return value is not compatible with
 *            getaddrinfo(3).
 * @sa getaddrinfo()
 *)
function coio_getaddrinfo(const host: pchar; const port: pchar;
		 const hints: addrinfo; res: paddrinfo;
		 timeout: Double): integer; cdecl; external;

(**
 * Transaction id - a non-persistent unique identifier
 * of the current transaction. -1 if there is no current
 * transaction.
 *)
function box_txn_id: Int64; cdecl; external;

(**
 * Return true if there is an active transaction.
 *)
function box_txn: boolean; cdecl; external;

(**
 * Begin a transaction in the current fiber.
 *
 * A transaction is attached to caller fiber, therefore one fiber can have
 * only one active transaction.
 *
 * @retval 0 - success
 * @retval -1 - failed, perhaps a transaction has already been
 * started
 *)
function box_txn_begin: Integer; cdecl; external;

(**
 * Commit the current transaction.
 * @retval 0 - success
 * @retval -1 - failed, perhaps a disk write failure.
 * started
 *)
function box_txn_commit: Integer; cdecl; external;

(**
 * Rollback the current transaction.
 * May fail if called from a nested
 * statement.
 *)
function box_txn_rollback: integer; cdecl; external;

(**
 * Allocate memory on txn memory pool.
 * The memory is automatically deallocated when the transaction
 * is committed or rolled back.
 *
 * @retval NULL out of memory
 *)
function box_txn_alloc(size: SIZE_T): pointer; cdecl; external;


type
  box_key_def_t = pointer;
  key_def = box_key_def_t;
  pkey_def = ^key_def;
  box_tuple_t = pointer;
  pbox_tuple_t = ^box_tuple_t;


  (**
   * Create key definition with key fields with passed typed on passed positions.
   * May be used for tuple format creation and/or tuple comparison.
   *
   * \param fields array with key field identifiers
   * \param types array with key field types (see enum field_type)
   * \param part_count the number of key fields
   * \returns a new key definition object
   *)
function box_key_def_new(fields: PUInt32; types: PUInt32; part_count: UInt32): box_key_def_t; cdecl; external;

  (**
   * Delete key definition
   *
   * \param key_def key definition to delete
   *)
procedure box_key_def_delete(key_def: box_key_def_t); cdecl; external;

  (**
   * Compare tuples using the key definition.
   * @param tuple_a first tuple
   * @param tuple_b second tuple
   * @param key_def key definition
   * @retval 0  if key_fields(tuple_a) == key_fields(tuple_b)
   * @retval <0 if key_fields(tuple_a) < key_fields(tuple_b)
   * @retval >0 if key_fields(tuple_a) > key_fields(tuple_b)
   *)
function  box_tuple_compare(const tuple_a: box_tuple_t; const tuple_b: box_tuple_t;
  		  key_def: box_key_def_t): integer; cdecl; external;

  (**
   * @brief Compare tuple with key using the key definition.
   * @param tuple tuple
   * @param key key with MessagePack array header
   * @param key_def key definition
   *
   * @retval 0  if key_fields(tuple) == parts(key)
   * @retval <0 if key_fields(tuple) < parts(key)
   * @retval >0 if key_fields(tuple) > parts(key)
   *)

function box_tuple_compare_with_key(const tuple_a: box_tuple_t; const key_b: PChar;
  			   key_def: box_key_def_t): integer; cdecl; external;


type field_type = (
	FIELD_TYPE_ANY = 0,
	FIELD_TYPE_UNSIGNED,
	FIELD_TYPE_STRING,
	FIELD_TYPE_NUMBER,
	FIELD_TYPE_INTEGER,
	FIELD_TYPE_BOOLEAN,
	FIELD_TYPE_SCALAR,
	FIELD_TYPE_ARRAY,
	FIELD_TYPE_MAP,
	field_type_MAX
);

type
  box_tuple_format_t = pointer;
  tuple_format = box_tuple_format_t;


  (**
   * Tuple Format.
   *
   * Each Tuple has associated format (class). Default format is used to
   * create tuples which are not attach to any particular space.
   *)
function  box_tuple_format_default: box_tuple_format_t; cdecl; external;

  (**
   * Tuple
   *)
// type tuple = box_tuple_t;

  (**
   * Increase the reference counter of tuple.
   *
   * Tuples are reference counted. All functions that return tuples guarantee
   * that the last returned tuple is refcounted internally until the next
   * call to API function that yields or returns another tuple.
   *
   * You should increase the reference counter before taking tuples for long
   * processing in your code. Such tuples will not be garbage collected even
   * if another fiber remove they from space. After processing please
   * decrement the reference counter using box_tuple_unref(), otherwise the
   * tuple will leak.
   *
   * \param tuple a tuple
   * \retval 0 always
   * \sa box_tuple_unref()
   *)
function box_tuple_ref(tuple: box_tuple_t): integer; cdecl; external;

  (**
   * Decrease the reference counter of tuple.
   *
   * \param tuple a tuple
   * \sa box_tuple_ref()
   *)
procedure box_tuple_unref(tuple: box_tuple_t); cdecl; external;

  (**
   * Return the number of fields in tuple (the size of MsgPack Array).
   * \param tuple a tuple
   *)
function box_tuple_field_count(const tuple: box_tuple_t): uint32; cdecl; external;

  (**
   * Return the number of bytes used to store internal tuple data (MsgPack Array).
   * \param tuple a tuple
   *)
function box_tuple_bsize(const tuple: box_tuple_t): size_t; cdecl; external;

  (**
   * Dump raw MsgPack data to the memory byffer \a buf of size \a size.
   *
   * Store tuple fields in the memory buffer.
   * \retval -1 on error.
   * \retval number of bytes written on success.
   * Upon successful return, the function returns the number of bytes written.
   * If buffer size is not enough then the return value is the number of bytes
   * which would have been written if enough space had been available.
   *)

function  box_tuple_to_buf(const tuple: box_tuple_t; buf: pchar; size: SIZE_T): ssize_t; cdecl; external;

  (**
   * Return the associated format.
   * \param tuple tuple
   * \return tuple_format
   *)
function  box_tuple_format(const tuple: box_tuple_t): box_tuple_format_t; cdecl; external;

  (**
   * Return the raw tuple field in MsgPack format.
   *
   * The buffer is valid until next call to box_tuple_* functions.
   *
   * \param tuple a tuple
   * \param fieldno zero-based index in MsgPack array.
   * \retval NULL if i >= box_tuple_field_count(tuple)
   * \retval msgpack otherwise
   *)
function box_tuple_field(const tuple: box_tuple_t; fieldno: UInt32): pchar; cdecl; external;

  (**
   * Tuple iterator
   *)
type
    tuple_iterator = pointer;
    box_tuple_iterator_t = tuple_iterator;

  (**
   * Allocate and initialize a new tuple iterator. The tuple iterator
   * allow to iterate over fields at root level of MsgPack array.
   *
   * Example:
   * \code
   * box_tuple_iterator *it = box_tuple_iterator(tuple);
   * if (it == NULL) {
   *      // error handling using box_error_last()
   * }
   * const char *field;
   * while (field = box_tuple_next(it)) {
   *      // process raw MsgPack data
   * }
   *
   * // rewind iterator to first position
   * box_tuple_rewind(it);
   * assert(box_tuple_position(it) == 0);
   *
   * // rewind iterator to first position
   * field = box_tuple_seek(it, 3);
   * assert(box_tuple_position(it) == 4);
   *
   * box_iterator_free(it);
   * \endcode
   *
   * \post box_tuple_position(it) == 0
   *)

function  box_tuple_iterator(tuple: box_tuple_t): box_tuple_iterator_t; cdecl; external;

  {**
   * Destroy and free tuple iterator
   *}
procedure box_tuple_iterator_free(it: box_tuple_iterator_t); cdecl; external;

  (**
   * Return zero-based next position in iterator.
   * That is, this function return the field id of field that will be
   * returned by the next call to box_tuple_next(it). Returned value is zero
   * after initialization or rewind and box_tuple_field_count(tuple)
   * after the end of iteration.
   *
   * \param it tuple iterator
   * \returns position.
   *)
function box_tuple_position(it: box_tuple_iterator_t): uint32; cdecl; external;

  (**
   * Rewind iterator to the initial position.
   *
   * \param it tuple iterator
   * \post box_tuple_position(it) == 0
   *)
procedure box_tuple_rewind(it: box_tuple_iterator_t); cdecl; external;

  (**
   * Seek the tuple iterator.
   *
   * The returned buffer is valid until next call to box_tuple_* API.
   * Requested fieldno returned by next call to box_tuple_next(it).
   *
   * \param it tuple iterator
   * \param fieldno - zero-based position in MsgPack array.
   * \post box_tuple_position(it) == fieldno if returned value is not NULL
   * \post box_tuple_position(it) == box_tuple_field_count(tuple) if returned
   * value is NULL.
   *)

function box_tuple_seek(it: box_tuple_iterator_t; fieldno: uint32): pchar; cdecl; external;

  (**
   * Return the next tuple field from tuple iterator.
   * The returned buffer is valid until next call to box_tuple_* API.
   *
   * \param it tuple iterator.
   * \retval NULL if there are no more fields.
   * \retval MsgPack otherwise
   * \pre box_tuple_position(it) is zerod-based id of returned field
   * \post box_tuple_position(it) == box_tuple_field_count(tuple) if returned
   * value is NULL.
   *)
function box_tuple_next(it: box_tuple_iterator_t): PChar; cdecl; external;

  (**
   * Allocate and initialize a new tuple from a raw MsgPack Array data.
   *
   * \param format tuple format.
   * Use box_tuple_format_default() to create space-independent tuple.
   * \param data tuple data in MsgPack Array format ([field1, field2, ...]).
   * \param end the end of \a data
   * \retval tuple
   * \pre data, end is valid MsgPack Array
   * \sa \code box.tuple.new(data) \endcode
   *)
function box_tuple_new(format: box_tuple_format_t; const data: pchar; const pend: PChar): box_tuple_t; cdecl; external;

function box_tuple_update(const tuple: box_tuple_t; const expr: pchar; const expr_end: pchar): box_tuple_t; cdecl; external;

function box_tuple_upsert(const tuple: box_tuple_t; const expr: pchar; const expr_end: pchar): box_tuple_t; cdecl; external;

  (**
   * Return new in-memory tuple format based on passed key definitions.
   *
   * \param keys array of keys defined for the format
   * \key_count count of keys
   * \retval new tuple format if success
   * \retval NULL for error
   *)

function box_tuple_format_new(keys: pkey_def; key_count: UInt16): box_tuple_format_t; cdecl; external;

  (**
   * Increment tuple format ref count.
   *
   * \param tuple_format the tuple format to ref
   *)
procedure box_tuple_format_ref(format: box_tuple_format_t); cdecl; external;

  (**
   * Decrement tuple format ref count.
   *
   * \param tuple_format the tuple format to unref
   *)
procedure box_tuple_format_unref(format: box_tuple_format_t); cdecl; external;

type system_spaces = (
  	//** Start of the reserved range of system spaces. *)
  	BOX_SYSTEM_ID_MIN = 256,
  	//** Space if of _vinyl_deferred_delete. *)
  	BOX_VINYL_DEFERRED_DELETE_ID = 257,
  	//** Space id of _schema. *)
  	BOX_SCHEMA_ID = 272,
  	//** Space id of _collation. *)
  	BOX_COLLATION_ID = 276,
  	//** Space id of _space. *)
  	BOX_SPACE_ID = 280,
  	//** Space id of _vspace view. *)
  	BOX_VSPACE_ID = 281,
  	//** Space id of _sequence. *)
  	BOX_SEQUENCE_ID = 284,
  	//** Space id of _sequence_data. *)
  	BOX_SEQUENCE_DATA_ID = 285,
  	//** Space id of _vsequence view. *)
  	BOX_VSEQUENCE_ID = 286,
  	//** Space id of _index. *)
  	BOX_INDEX_ID = 288,
  	//** Space id of _vindex view. *)
  	BOX_VINDEX_ID = 289,
  	//** Space id of _func. *)
  	BOX_FUNC_ID = 296,
  	//** Space id of _vfunc view. *)
  	BOX_VFUNC_ID = 297,
  	//** Space id of _user. *)
  	BOX_USER_ID = 304,
  	//** Space id of _vuser view. *)
  	BOX_VUSER_ID = 305,
  	//** Space id of _priv. *)
  	BOX_PRIV_ID = 312,
  	//** Space id of _vpriv view. *)
  	BOX_VPRIV_ID = 313,
  	//** Space id of _cluster. *)
  	BOX_CLUSTER_ID = 320,
  	//** Space id of _truncate. *)
  	BOX_TRUNCATE_ID = 330,
  	//** Space id of _space_sequence. *)
  	BOX_SPACE_SEQUENCE_ID = 340,
  	//** End of the reserved range of system spaces. *)
  	BOX_SYSTEM_ID_MAX = 511,
  	BOX_ID_NIL = 2147483647
  );

  (*
   * Opaque structure passed to the stored C procedure
   *)
type
 box_function_ctx = pointer;
 box_function_ctx_t = box_function_ctx;

  (**
   * Return a tuple from stored C procedure.
   *
   * Returned tuple is automatically reference counted by Tarantool.
   *
   * \param ctx an opaque structure passed to the stored C procedure by
   * Tarantool
   * \param tuple a tuple to return
   * \retval -1 on error (perhaps, out of memory; check box_error_last())
   * \retval 0 otherwise
   *)
function box_return_tuple(ctx: box_function_ctx_t; tuple: box_tuple_t): integer; cdecl; external;

  (**
   * Find space id by name.
   *
   * This function performs SELECT request to _vspace system space.
   * \param name space name
   * \param len length of \a name
   * \retval BOX_ID_NIL on error or if not found (check box_error_last())
   * \retval space_id otherwise
   * \sa box_index_id_by_name
   *)
function box_space_id_by_name(const name: pchar; len: UInt32): uint32; cdecl; external;

  (**
   * Find index id by name.
   *
   * This function performs SELECT request to _vindex system space.
   * \param space_id space identifier
   * \param name index name
   * \param len length of \a name
   * \retval BOX_ID_NIL on error or if not found (check box_error_last())
   * \retval index_id otherwise
   * \sa box_space_id_by_name
   *)
function box_index_id_by_name(space_id: UInt32; const name: PChar; len: UInt32): UInt32; cdecl; external;

  (**
   * Execute an INSERT request.
   *
   * \param space_id space identifier
   * \param tuple encoded tuple in MsgPack Array format ([ field1, field2, ...])
   * \param tuple_end end of @a tuple
   * \param[out] result a new tuple. Can be set to NULL to discard result.
   * \retval -1 on error (check box_error_last())
   * \retval 0 on success
   * \sa \code box.space[space_id]:insert(tuple) \endcode
   *)
function box_insert(space_id: UInt32; const tuple: PChar; const tuple_end: PChar; result: pbox_tuple_t): integer; cdecl; external;

  (**
   * Execute an REPLACE request.
   *
   * \param space_id space identifier
   * \param tuple encoded tuple in MsgPack Array format ([ field1, field2, ...])
   * \param tuple_end end of @a tuple
   * \param[out] result a new tuple. Can be set to NULL to discard result.
   * \retval -1 on error (check box_error_last())
   * \retval 0 on success
   * \sa \code box.space[space_id]:replace(tuple) \endcode
   *)
function box_replace(space_id: UInt32; const tuple: PChar; const tuple_end: PChar;
  	    result: pbox_tuple_t): integer; cdecl; external;

  (**
   * Execute an DELETE request.
   *
   * \param space_id space identifier
   * \param index_id index identifier
   * \param key encoded key in MsgPack Array format ([part1, part2, ...]).
   * \param key_end the end of encoded \a key.
   * \param[out] result an old tuple. Can be set to NULL to discard result.
   * \retval -1 on error (check box_error_last())
   * \retval 0 on success
   * \sa \code box.space[space_id].index[index_id]:delete(key) \endcode
   *)
function box_delete(space_id: UInt32; index_id: UInt32; const key: PChar;
  	   const key_end: PChar; result: pbox_tuple_t): integer; cdecl; external;

  (**
   * Execute an UPDATE request.
   *
   * \param space_id space identifier
   * \param index_id index identifier
   * \param key encoded key in MsgPack Array format ([part1, part2, ...]).
   * \param key_end the end of encoded \a key.
   * \param ops encoded operations in MsgPack Arrat format, e.g.
   * [ [ '=', fieldno,  value ],  ['!', 2, 'xxx'] ]
   * \param ops_end the end of encoded \a ops
   * \param index_base 0 if fieldnos in update operations are zero-based
   * indexed (like C) or 1 if for one-based indexed field ids (like Lua).
   * \param[out] result a new tuple. Can be set to NULL to discard result.
   * \retval -1 on error (check box_error_last())
   * \retval 0 on success
   * \sa \code box.space[space_id].index[index_id]:update(key, ops) \endcode
   * \sa box_upsert()
   *)
function box_update(space_id: UInt32; index_id: UInt32; const key: PChar;
  	   const key_end: PChar; const ops: PChar; const ops_end: PChar;
  	   index_base: integer; result: pbox_tuple_t): integer; cdecl; external;

  (**
   * Execute an UPSERT request.
   *
   * \param space_id space identifier
   * \param index_id index identifier
   * \param ops encoded operations in MsgPack Arrat format, e.g.
   * [ [ '=', fieldno,  value ],  ['!', 2, 'xxx'] ]
   * \param ops_end the end of encoded \a ops
   * \param tuple encoded tuple in MsgPack Array format ([ field1, field2, ...])
   * \param tuple_end end of @a tuple
   * \param index_base 0 if fieldnos in update operations are zero-based
   * indexed (like C) or 1 if for one-based indexed field ids (like Lua).
   * \param[out] result a new tuple. Can be set to NULL to discard result.
   * \retval -1 on error (check box_error_last())
   * \retval 0 on success
   * \sa \code box.space[space_id].index[index_id]:update(key, ops) \endcode
   * \sa box_update()
   *)
function  box_upsert(space_id: UInt32; index_id: UInt32; const tuple: PChar;
  	   const tuple_end: PChar; const ops: PChar; const ops_end: PChar;
  	   index_base: integer; result: pbox_tuple_t): integer; cdecl; external;

  (**
   * Truncate space.
   *
   * \param space_id space identifier
   *)
function box_truncate(space_id: UInt32): Integer; cdecl; external;

  (**
   * Advance a sequence.
   *
   * \param seq_id sequence identifier
   * \param[out] result pointer to a variable where the next sequence
   * value will be stored on success
   * \retval -1 on error (check box_error_last())
   * \retval 0 on success
   *)
function  box_sequence_next(seq_id: UInt32; var result: Int64): integer; cdecl; external;

  (**
   * Set a sequence value.
   *
   * \param seq_id sequence identifier
   * \param value new sequence value; on success the next call to
   * box_sequence_next() will return the value following \a value
   * \retval -1 on error (check box_error_last())
   * \retval 0 on success
   *)
function box_sequence_set(seq_id: UInt32; value: Int64): Integer; cdecl; external;

  (**
   * Reset a sequence.
   *
   * \param seq_id sequence identifier
   * \retval -1 on error (check box_error_last())
   * \retval 0 on success
   *)
function box_sequence_reset(seq_id: UInt32): integer; cdecl; external;


type
    box_iterator_t = pointer;

  (**
   * Allocate and initialize iterator for space_id, index_id.
   *
   * A returned iterator must be destroyed by box_iterator_free().
   *
   * \param space_id space identifier.
   * \param index_id index identifier.
   * \param type \link iterator_type iterator type \endlink
   * \param key encoded key in MsgPack Array format ([part1, part2, ...]).
   * \param key_end the end of encoded \a key
   * \retval NULL on error (check box_error_last())
   * \retval iterator otherwise
   * \sa box_iterator_next()
   * \sa box_iterator_free()
   *)


function box_index_iterator(space_id: UInt32; index_id: UInt32; atype: Integer;
  		   const key: PChar; const key_end: PChar): box_iterator_t; cdecl; external;
  (**
   * Retrive the next item from the \a iterator.
   *
   * \param iterator an iterator returned by box_index_iterator().
   * \param[out] result a tuple or NULL if there is no more data.
   * \retval -1 on error (check box_error_last() for details)
   * \retval 0 on success. The end of data is not an error.
   *)
function box_iterator_next(iterator: box_iterator_t; result: pbox_tuple_t): Integer; cdecl; external;

  (**
   * Destroy and deallocate iterator.
   *
   * \param iterator an interator returned by box_index_iterator()
   *)
procedure box_iterator_free(it: box_iterator_t); cdecl; external;

  (**
   * Return the number of element in the index.
   *
   * \param space_id space identifier
   * \param index_id index identifier
   * \retval -1 on error (check box_error_last())
   * \retval >= 0 otherwise
   *)
function  box_index_len(space_id: UInt32; index_id: UInt32): ssize_t; cdecl; external;

  (**
   * Return the number of bytes used in memory by the index.
   *
   * \param space_id space identifier
   * \param index_id index identifier
   * \retval -1 on error (check box_error_last())
   * \retval >= 0 otherwise
   *)
function box_index_bsize(space_id: UInt32; index_id: UInt32): ssize_t; cdecl; external;

  (**
   * Return a random tuple from the index (useful for statistical analysis).
   *
   * \param space_id space identifier
   * \param index_id index identifier
   * \param rnd random seed
   * \param[out] result a tuple or NULL if index is empty
   * \retval -1 on error (check box_error_last())
   * \retval 0 on success
   * \sa \code box.space[space_id].index[index_id]:random(rnd) \endcode
   *)
function  box_index_random(space_id: UInt32; index_id: UInt32; rnd: uint32;
  		result: pbox_tuple_t): integer; cdecl; external;

  (**
   * Get a tuple from index by the key.
   *
   * Please note that this function works much more faster than
   * box_select() or box_index_iterator() + box_iterator_next().
   *
   * \param space_id space identifier
   * \param index_id index identifier
   * \param key encoded key in MsgPack Array format ([part1, part2, ...]).
   * \param key_end the end of encoded \a key
   * \param[out] result a tuple or NULL if index is empty
   * \retval -1 on error (check box_error_last())
   * \retval 0 on success
   * \pre key != NULL
   * \sa \code box.space[space_id].index[index_id]:get(key) \endcode
   *)
function box_index_get(space_id: uint32; index_id: uint32; const key: pchar;
  	      const key_end: pchar; result: pbox_tuple_t): Integer; cdecl; external;

  (**
   * Return a first (minimal) tuple matched the provided key.
   *
   * \param space_id space identifier
   * \param index_id index identifier
   * \param key encoded key in MsgPack Array format ([part1, part2, ...]).
   * \param key_end the end of encoded \a key.
   * \param[out] result a tuple or NULL if index is empty
   * \retval -1 on error (check box_error_last())
   * \retval 0 on success
   * \sa \code box.space[space_id].index[index_id]:min(key) \endcode
   *)
function box_index_min(space_id: uint32; index_id: uint32; const key: pchar;
  	      const key_end: pchar; result: pbox_tuple_t): integer; cdecl; external;

  (**
   * Return a last (maximal) tuple matched the provided key.
   *
   * \param space_id space identifier
   * \param index_id index identifier
   * \param key encoded key in MsgPack Array format ([part1, part2, ...]).
   * \param key_end the end of encoded \a key.
   * \param[out] result a tuple or NULL if index is empty
   * \retval -1 on error (check box_error_last())
   * \retval 0 on success
   * \sa \code box.space[space_id].index[index_id]:max(key) \endcode
   *)
function box_index_max(space_id: uint32; index_id: uint32; const key: pchar;
  	      const key_end: pchar; result: pbox_tuple_t): integer; cdecl; external;

  (**
   * Count the number of tuple matched the provided key.
   *
   * \param space_id space identifier
   * \param index_id index identifier
   * \param type iterator type - enum \link iterator_type \endlink
   * \param key encoded key in MsgPack Array format ([part1, part2, ...]).
   * \param key_end the end of encoded \a key.
   * \retval -1 on error (check box_error_last())
   * \retval >=0 on success
   * \sa \code box.space[space_id].index[index_id]:count(key,
   *     { iterator = type }) \endcode
   *)
//  ssize_t
function  box_index_count(space_id: uint32; index_id: uint32; atype: integer;
  		const key: pchar; const key_end: pchar): ssize_t; cdecl; external;

  (**
   * Extract key from tuple according to key definition of given
   * index. Returned buffer is allocated on box_txn_alloc() with
   * this key.
   * @param tuple Tuple from which need to extract key.
   * @param space_id Space identifier.
   * @param index_id Index identifier.
   * @retval not NULL Success
   * @retval     NULL Memory Allocation error
   *)
function box_tuple_extract_key(const tuple: box_tuple_t; space_id: UInt32;
  		      index_id: UInt32; var key_size: UInt32): pchar; cdecl; external;


  (**
   * Controls how to iterate over tuples in an index.
   * Different index types support different iterator types.
   * For example, one can start iteration from a particular value
   * (request key) and then retrieve all tuples where keys are
   * greater or equal (= GE) to this key.
   *
   * If iterator type is not supported by the selected index type,
   * iterator constructor must fail with ER_UNSUPPORTED. To be
   * selectable for primary key, an index must support at least
   * ITER_EQ and ITER_GE types.
   *
   * NULL value of request key corresponds to the first or last
   * key in the index, depending on iteration direction.
   * (first key for GE and GT types, and last key for LE and LT).
   * Therefore, to iterate over all tuples in an index, one can
   * use ITER_GE or ITER_LE iteration types with start key equal
   * to NULL.
   * For ITER_EQ, the key must not be NULL.
   *)
type iterator_type = (
  	//* ITER_EQ must be the first member for request_create  *)
  	ITER_EQ               =  0, //* key == x ASC order                  *)
  	ITER_REQ              =  1, //* key == x DESC order                 *)
  	ITER_ALL              =  2, //* all tuples                          *)
  	ITER_LT               =  3, //* key <  x                            *)
  	ITER_LE               =  4, //* key <= x                            *)
  	ITER_GE               =  5, //* key >= x                            *)
  	ITER_GT               =  6, //* key >  x                            *)
  	ITER_BITS_ALL_SET     =  7, //* all bits from x are set in key      *)
  	ITER_BITS_ANY_SET     =  8, //* at least one x's bit is set         *)
  	ITER_BITS_ALL_NOT_SET =  9, //* all bits are not set                *)
  	ITER_OVERLAPS         = 10, //* key overlaps x                      *)
  	ITER_NEIGHBOR         = 11, //* tuples in distance ascending order from specified point *)
  	iterator_type_MAX
  );


type
  tnterror = pointer;
  (**
   * Error - contains information about error.
   *)
type
  box_error_t = tnterror;

  (**
   * Return the error type, e.g. "ClientError", "SocketError", etc.
   * \param error
   * \return not-null string
   *)
function box_error_type(const error: box_error_t): pchar; cdecl; external;

  (**
   * Return IPROTO error code
   * \param error error
   * \return enum box_error_code
   *)
function box_error_code(const error: box_error_t): uint32; cdecl; external;

  (**
   * Return the error message
   * \param error error
   * \return not-null string
   *)
function box_error_message(const error: box_error_t): pchar; cdecl; external;

  (**
   * Get the information about the last API call error.
   *
   * The Tarantool error handling works most like libc's errno. All API calls
   * return -1 or NULL in the event of error. An internal pointer to
   * box_error_t type is set by API functions to indicate what went wrong.
   * This value is only significant if API call failed (returned -1 or NULL).
   *
   * Successful function can also touch the last error in some
   * cases. You don't have to clear the last error before calling
   * API functions. The returned object is valid only until next
   * call to **any** API function.
   *
   * You must set the last error using box_error_set() in your stored C
   * procedures if you want to return a custom error message.
   * You can re-throw the last API error to IPROTO client by keeping
   * the current value and returning -1 to Tarantool from your
   * stored procedure.
   *
   * \return last error.
   *)
function box_error_last: box_error_t; cdecl; external;

  (**
   * Clear the last error.
   *)
procedure box_error_clear; cdecl; external;

  (**
   * Set the last error.
   *
   * \param code IPROTO error code (enum \link box_error_code \endlink)
   * \param format (const char * ) - printf()-like format string
   * \param ... - format arguments
   * \returns -1 for convention use
   *
   * \sa enum box_error_code
   *)
//function  box_error_set(const char *file, unsigned line, uint32_t code,
//  	      const char *format, ...): integer;

  (**
   * A backward-compatible API define.
   *)
//  #define box_error_raise(code, format, ...) \
//  	box_error_set(__FILE__, __LINE__, code, format, ##__VA_ARGS__)


  (**
   * Push a tuple onto the stack.
   * @param L Lua State
   * @sa luaT_istuple
   * @throws on OOM
   *)
//  void
//  luaT_pushtuple(struct lua_State *L, box_tuple_t *tuple);

  (**
   * Checks whether argument idx is a tuple
   *
   * @param L Lua State
   * @param idx the stack index
   * @retval non-NULL argument is tuple
   * @retval NULL argument is not tuple
   *)
//  box_tuple_t *
//  luaT_istuple(struct lua_State *L, int idx);


  (**
   * A lock for cooperative multitasking environment
   *)
type
  box_latch = Pointer;
  box_latch_t = box_latch;

  (**
   * Allocate and initialize the new latch.
   * \returns latch
   *)
function box_latch_new: box_latch_t; cdecl; external;

  (**
   * Destroy and free the latch.
   * \param latch latch
   *)
procedure box_latch_delete(latch: box_latch_t); cdecl; external;

  (**
  * Lock a latch. Waits indefinitely until the current fiber can gain access to
  * the latch.
  *
  * \param latch a latch
  *)
procedure box_latch_lock(latch: box_latch_t); cdecl; external;

  (**
   * Try to lock a latch. Return immediately if the latch is locked.
   * \param latch a latch
   * \retval 0 - success
   * \retval 1 - the latch is locked.
   *)
function box_latch_trylock(latch: box_latch_t): integer; cdecl; external;

  (**
   * Unlock a latch. The fiber calling this function must
   * own the latch.
   *
   * \param latch a latch
   *)
procedure box_latch_unlock(latch: box_latch_t); cdecl; external;


function clock_realtime: double;  cdecl; external;
function clock_monotonic: Double; cdecl; external;
function clock_process: Double; cdecl; external;
function clock_thread: Double; cdecl; external;

function clock_realtime64: uint64; cdecl; external;
function clock_monotonic64: uint64; cdecl; external;
function clock_process64: uint64; cdecl; external;
function clock_thread64: uint64; cdecl; external;

type enum_box_error_code = (ER_UNKNOWN, ER_ILLEGAL_PARAMS, ER_MEMORY_ISSUE, ER_TUPLE_FOUND, ER_TUPLE_NOT_FOUND, ER_UNSUPPORTED, ER_NONMASTER, ER_READONLY, ER_INJECTION, ER_CREATE_SPACE, ER_SPACE_EXISTS, ER_DROP_SPACE, ER_ALTER_SPACE, ER_INDEX_TYPE, ER_MODIFY_INDEX, ER_LAST_DROP, ER_TUPLE_FORMAT_LIMIT, ER_DROP_PRIMARY_KEY, ER_KEY_PART_TYPE, ER_EXACT_MATCH, ER_INVALID_MSGPACK, ER_PROC_RET, ER_TUPLE_NOT_ARRAY, ER_FIELD_TYPE, ER_INDEX_PART_TYPE_MISMATCH, ER_SPLICE, ER_UPDATE_ARG_TYPE, ER_FORMAT_MISMATCH_INDEX_PART, ER_UNKNOWN_UPDATE_OP, ER_UPDATE_FIELD, ER_FUNCTION_TX_ACTIVE, ER_KEY_PART_COUNT, ER_PROC_LUA, ER_NO_SUCH_PROC, ER_NO_SUCH_TRIGGER, ER_NO_SUCH_INDEX, ER_NO_SUCH_SPACE, ER_NO_SUCH_FIELD, ER_EXACT_FIELD_COUNT, ER_MIN_FIELD_COUNT, ER_WAL_IO, ER_MORE_THAN_ONE_TUPLE, ER_ACCESS_DENIED, ER_CREATE_USER, ER_DROP_USER, ER_NO_SUCH_USER, ER_USER_EXISTS, ER_PASSWORD_MISMATCH, ER_UNKNOWN_REQUEST_TYPE, ER_UNKNOWN_SCHEMA_OBJECT, ER_CREATE_FUNCTION, ER_NO_SUCH_FUNCTION, ER_FUNCTION_EXISTS, ER_BEFORE_REPLACE_RET, ER_FUNCTION_MAX, ER_UNUSED4, ER_USER_MAX, ER_NO_SUCH_ENGINE, ER_RELOAD_CFG, ER_CFG, ER_SAVEPOINT_EMPTY_TX, ER_NO_SUCH_SAVEPOINT, ER_UNKNOWN_REPLICA, ER_REPLICASET_UUID_MISMATCH, ER_INVALID_UUID, ER_REPLICASET_UUID_IS_RO, ER_INSTANCE_UUID_MISMATCH, ER_REPLICA_ID_IS_RESERVED, ER_INVALID_ORDER, ER_MISSING_REQUEST_FIELD, ER_IDENTIFIER, ER_DROP_FUNCTION, ER_ITERATOR_TYPE, ER_REPLICA_MAX, ER_INVALID_XLOG, ER_INVALID_XLOG_NAME, ER_INVALID_XLOG_ORDER, ER_NO_CONNECTION, ER_TIMEOUT, ER_ACTIVE_TRANSACTION, ER_CURSOR_NO_TRANSACTION, ER_CROSS_ENGINE_TRANSACTION, ER_NO_SUCH_ROLE, ER_ROLE_EXISTS, ER_CREATE_ROLE, ER_INDEX_EXISTS, ER_UNUSED6, ER_ROLE_LOOP, ER_GRANT, ER_PRIV_GRANTED, ER_ROLE_GRANTED, ER_PRIV_NOT_GRANTED, ER_ROLE_NOT_GRANTED, ER_MISSING_SNAPSHOT, ER_CANT_UPDATE_PRIMARY_KEY, ER_UPDATE_INTEGER_OVERFLOW, ER_GUEST_USER_PASSWORD, ER_TRANSACTION_CONFLICT, ER_UNSUPPORTED_PRIV, ER_LOAD_FUNCTION, ER_FUNCTION_LANGUAGE, ER_RTREE_RECT, ER_PROC_C, ER_UNKNOWN_RTREE_INDEX_DISTANCE_TYPE, ER_PROTOCOL, ER_UPSERT_UNIQUE_SECONDARY_KEY, ER_WRONG_INDEX_RECORD, ER_WRONG_INDEX_PARTS, ER_WRONG_INDEX_OPTIONS, ER_WRONG_SCHEMA_VERSION, ER_MEMTX_MAX_TUPLE_SIZE, ER_WRONG_SPACE_OPTIONS, ER_UNSUPPORTED_INDEX_FEATURE, ER_VIEW_IS_RO, ER_SAVEPOINT_NO_TRANSACTION, ER_SYSTEM, ER_LOADING, ER_CONNECTION_TO_SELF, ER_KEY_PART_IS_TOO_LONG, ER_COMPRESSION, ER_CHECKPOINT_IN_PROGRESS, ER_SUB_STMT_MAX, ER_COMMIT_IN_SUB_STMT, ER_ROLLBACK_IN_SUB_STMT, ER_DECOMPRESSION, ER_INVALID_XLOG_TYPE, ER_ALREADY_RUNNING, ER_INDEX_FIELD_COUNT_LIMIT, ER_LOCAL_INSTANCE_ID_IS_READ_ONLY, ER_BACKUP_IN_PROGRESS, ER_READ_VIEW_ABORTED, ER_INVALID_INDEX_FILE, ER_INVALID_RUN_FILE, ER_INVALID_VYLOG_FILE, ER_CHECKPOINT_ROLLBACK, ER_VY_QUOTA_TIMEOUT, ER_PARTIAL_KEY, ER_TRUNCATE_SYSTEM_SPACE, ER_LOAD_MODULE, ER_VINYL_MAX_TUPLE_SIZE, ER_WRONG_DD_VERSION, ER_WRONG_SPACE_FORMAT, ER_CREATE_SEQUENCE, ER_ALTER_SEQUENCE, ER_DROP_SEQUENCE, ER_NO_SUCH_SEQUENCE, ER_SEQUENCE_EXISTS, ER_SEQUENCE_OVERFLOW, ER_UNUSED5, ER_SPACE_FIELD_IS_DUPLICATE, ER_CANT_CREATE_COLLATION, ER_WRONG_COLLATION_OPTIONS, ER_NULLABLE_PRIMARY, ER_UNUSED, ER_TRANSACTION_YIELD, ER_NO_SUCH_GROUP, box_error_code_MAX);

{$EndIf}

implementation

end.
