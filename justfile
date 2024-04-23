set positional-arguments
set dotenv-load

@sign message:
	echo "-> Signing $1" && \
	bun utils/ffi.ts signMessage $1

@safe-run script func: 
	forge script $1 --sig "$2()" --ffi -vvv && \
	echo "-> $1.$2() ran successfully" && \
	echo "-> Sending (signature required).." && \
	forge script SafeScript --sig "sendBatch(string)" $2 --ffi -vvv && \
	echo "-> Sent!"

@safe-run-nonce script func nonce: 
	forge script $1 --sig "$2()" --ffi -vvv && \
	echo "-> $1.$2() ran successfully" && \
	echo "-> Sending (signature required).." && \
	forge script SafeScript --sig "sendBatch(string,uint256)" $2 $3 --ffi -vvv && \
	echo "-> Sent!"

@safe-file batchfile:
	echo "-> Sending $1.." && \
	bun utils/ffi.ts proposeBatch $1 true && \
	echo "-> Sent!"

@safe-del safeTxHash:
	echo "-> Sign to delete $1" && \
	bun utils/ffi.ts deleteBatch $1 && \
	echo "-> Deleted $1"